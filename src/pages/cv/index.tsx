import { FC } from 'react';
import Link from 'next/link';

type Props = {};

const CVPage: FC<Props> = () => {
    return (
        <>
            <h1>Hello, this is my CV</h1>
            <Link href="/">Go home</Link>
        </>
    );
};

export default CVPage;